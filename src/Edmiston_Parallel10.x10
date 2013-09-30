/*
 *
 * (C) Copyright IBM Corporation 2006
 *
 *  This file is part of X10 Test.
 *
 */
import harness.x10Test;;

/**
 * A parallel version of Edmiston's algorithm for sequence alignment, written in X10.
 *
 * This code is an X10 port of the Edmiston_Sequential.c program written by
 * Sirisha Muppavarapu (sirisham@cs.unm.edu), U. New Mexico.
 *
 * @author Vivek Sarkar (vsarkar@us.ibm.com)
 * @author Kemal Ebcioglu (kemal@us.ibm.com)
 * @author Tiago Cogumbreiro (cogumbreiro@di.fc.ul.pt) (ported to X10 2.1)
 *
 * This version splits work across columns of the (N+1)*(M+1)
 * matrix (where N<M), taking advantage of the domain
 * knowledge that only
 * a pre-computation of the preceding 1.5*N columns are
 * necessary, for "warming up" the computation for the current
 * block.
 *
 * Both inter-place and intra-place  parallelism exploited in this version.
 * Intra -place parallelism is achieved through a recursive method and clocks.
 */
public class Edmiston_Parallel10 {

	public def run(): Boolean {
		val N = 10; //#rows
		val M = 100; //#columns
		val EXPECTED_CHECKSUM = -402;
		var r: Random = new Random(1);
		// Create two random char strings of lengths N and M
		var c1: RandCharStr = new RandCharStr(r, N);
		var c2: RandCharStr = new RandCharStr(r, M);
		// Create an output matrix for inputs c1 and c2
		var m: EditDistMatrix = new EditDistMatrix(c1, c2);
		// Print the matrix
		m.printMatrix();
		// Print abstract performance metrics
		m.printMetrics();
		// Verify result against expected.
		m.verify(EXPECTED_CHECKSUM);
		return true;
	}

	public static def main(var args: Rail[String]): void = {
		new Edmiston_Parallel10().execute();
	}

	/**
	 * Class implementing data structures and operations for an edit distance matrix.
	 */
	static class EditDistMatrix {
		public val iGapPen = 2;
		public val iMatch = -1 ;
		public val iMisMatch = 1;

		public val e: Array[Int](1); // the edit distance matrix
		val c1: RandCharStr; // input string 1
		val c2: RandCharStr; // input string 2
		val N: Int; // matrix dimensions
		val M: Int;

		/**
		 * Constructor method: create the edit distance matrix using Edmiston's algorithm,
		 * from the input strings cSeq1 and cSeq2.
		 */
		public def this(var cSeq1: RandCharStr, var cSeq2: RandCharStr): EditDistMatrix {
			c1 = cSeq1;
			c2 = cSeq2;
			N = c1.s.region.high();
			M = c2.s.region.high();

			val D: dist{rank==2} = (dist{rank==2})) starBlock([0..N], [0..M]);

			e = new Array[Int](D);

			// compute required number of overlap columns
			// with preceding block
			val overlap: Int = ceilFrac(N*(-iMatch), iGapPen)+N;

			// parallel independent computation at each place
			finish for (p in Place.places()) {
			    async at(p) {
			    ateach (val (p): point in distmakeUnique(D.places())) {
				// get sub-distribution for this place
				val myD: dist{rank==2} = D | here;
				// extend it on the left with extra overlap columns
				var origStartColumn: Int = myD.region.rank(1).low();
				val myExtendedD: dist{rank==2} = myD || (Dist.makeConstant([0..N, Math.max(0..origStartColumn-overlap, (origStartColumn-1))], here));

				// Create a local array including overlap columns
				val B = new Array[Int](myExtendedD);

				// Do sequence alignment on local array including the
				// overlap columns. Row 0 and Column 0 are all 0's
				// and do not need to be computed.

				val endRow = myExtendedD.region.rank(0).high();
				val endColumn = myExtendedD.region.rank(1).high();
				val startRow = myExtendedD.region.rank(0).low()+1;
				val startColumn = myExtendedD.region.rank(1).low()+1;

				// Recursive method to compute each "wave" in parallel
				finish async {
					final val c: clock = clock.factory.clock();
					computeRow(B, c, startRow, endRow, startColumn, endColumn);
				}

				// now copy the non-overlap columns to the answer array.
				finish foreach (val (i,j): point in myD) e(i, j) = B(i, j);
				}
			}
		}

		/**
		 * In the given current row of matrix B, compute the first element, and
		 * do a barrier sync ("next" on the clock c).
		 * If this is not the last row of B,
		 * recursively spawn the computation for the next row,
		 * registered on the same clock c.
		 * Then, for each remaining element in the current row,
		 * compute the element, and do a barrier sync ("next" on clock c).
		 * Finally the current activity dies,
		 * un-registering itself with the clock c.
		 *
		 * To be called initially with
		 * computeRow(B, c, startRow, endRow, startColumn, endColumn).
		 *
		 * In effect, this recursive method causes the elements of each 'wave'
		 * in the matrix B to be
		 * computed in parallel, with each wave computation followed by
		 * a barrier synchronization:
		 *
		 * 1st wave = { (startRow, startColumn) }
		 *
		 * 2nd wave = { (startRow+1, startColumn), (startRow, startColumn+1) }
		 *
		 * 3rd wave = { (startRow+2, startColumn), (startRow+1, startColumn+1), (startRow, startColumn+2) }
		 *
		 * and so on.
		 */
		def computeRow(val B: Array[Int], val c: clock, val currentRow: Int, val endRow: Int, val startColumn: Int, val endColumn: Int): void = {
			computeElement(B, currentRow, startColumn);
			next;
			if (currentRow < endRow) async clocked(c) computeRow(B, c, currentRow+1, endRow, startColumn, endColumn);
			for (val (currentColumn): point in [Region.makeRange((startColumn+1), endColumn)]) {
				computeElement(B, currentRow, currentColumn);
				next;
			}
		}

		/**
		 * Compute element (i,j) of B, based on its North, West and
		 * Northwest neighbors. All are guaranteed to be at the same place.
		 */
		def computeElement(val B: Array[Int], val i: Int, val j: Int): void = {
			B(i, j) = min4(0, B(i-1, j)+iGapPen, B(i, j-1)+iGapPen,
					B(i-1, j-1)+
					(c1.s(i) == c2.s(j) ? iMatch : iMisMatch));
		}

		/**
		 * Return a (*,block) distribution for
		 * the region (r1*r2)
		 */
		static def starBlock(var r1: region{rank==1}, var r2: region{rank==1}): dist{rank==2} = {
			var column2Place: dist = distmakeBlock(r2);
			var d: dist{rank==2} = Dist.makeConstant([0..-1, 0..-1], here); // a dist. with empty domain
			for (val (j): point in r2) d = d || (Dist.makeConstant([r1, j..j], column2Place(j)));
			return d;
		}

		/**
		 * Return element i,j of matrix.
		 * This could possibly be a remote read.
		 */
		def rdElem(val i: Int, val j: Int): Int = {
			return future(e.dist(i, j)) { e(i, j) }.force();
		}

		/**
		 * Print the Edit Distance Matrix.
		 */
		public def printMatrix(): void = {
			System.out.println("Minimum Matrix EditDistance is: " + rdElem(N, M));
			System.out.println("Matrix EditDistance is:");
			System.out.print(pad(' '));
			for (val (j): point in [0..M]) System.out.print(pad(c2.s(j)));
			System.out.println();

			for (val (i): point in [0..N]) {
				System.out.print(pad(c1.s(i)));
				for (val (j): point in [0..M]) System.out.print(pad(rdElem(i, j)));
				System.out.println();
			}
		}

		/**
		 * Print abstract performance metrics
		 */
		def printMetrics(): void = {
			System.out.println("**** START OF ABSTRACT PERFORMANCE METRICS ****");
			System.out.println("e.dist.distEfficiency() = " + e.dist.distEfficiency());
			System.out.println("N = " + N);
			System.out.println("M = " + M);
			System.out.println("nRows = " + e.region.rank(0).size());
			System.out.println("nCols = " + e.region.rank(1).size());
			final val P: Int = place.MAX_PLACES;
			System.out.println("P = " + P);
			final val T: Int = min4Count.sum();
			System.out.println("T = " + T);
			final val X: Int = min4Count.max();
			System.out.println("X = " + X);
			final val Tpar: Int = Math.max(ceilFrac(T, P), X);
			System.out.println("Tpar = " + Tpar);
			var S: float = (float) M*N / (float) Tpar;
			System.out.println("S = " + S);
			System.out.println();
			System.out.println("NOTES: 1) These metrics are only valid if your program satisfies the X10 Locality Rule");
			System.out.println("       2) It is recommended that you use -DUMP_STATS_ON_EXIT = true option with metrics");
			System.out.println("       3) In the current performance model, Tpar will always be the same as X.");
			System.out.println("          In a more sophisticated model, X will also include the effect of intra-place activities.");
			System.out.println("**** END OF ABSTRACT PERFORMANCE METRICS ***");
		}

		/**
		 * Verify that the sum of e is equal to the expected value
		 */
		public def verify(var expectedCheckSum: Int): void = {
			chk(e.sum() == expectedCheckSum);
		}

		/*
		 * Utility methods.
		 */

		/**
		 * Return ceil(n/m) for positive integers n and m
		 */
		static def ceilFrac(var n: Int, var m: Int): Int = {
			return (n+m-1)/m;
		}

		val min4Count: Array[Int] = new Array[Int](distmakeUnique()); // Array to support counting of MIN4 operations.

		/**
		 * returns the minimum of 4 integers.
		 */
		def min4(var w: Int, var x: Int, var y: Int, var z: Int): Int = {
			final val myP: place = here;
			finish async(myP) atomic min4Count((myP).id) += 1;
			return Math.min(Math.min(w, x), Math.min(y, z));
		}

		/**
		 * pad() methods for different data types
		 * Output string = input value converted to a string of length >= 3, with a blank inserted at the start and end.
		 */
		static def pad(var x: Int): String = { return pad(x + ""); }
		static def pad(var x: char): String = { return pad(x + ""); }
		static def pad(var s: String): String = {
			final val n: Int = 3;
			while (s.length() < n) s = " "+s;
			return " "+s+" ";
		}
	}

	/**
	 * Common random number generator class.
	 */
	static class Random {

		var randomSeed: Int;

		/**
		 * Create a new random number generator with seed x
		 */
		public def this(var x: Int): Random = {
			randomSeed = x;
		}

		/**
		 * Returns the next random number between 0 and 128,
		 * according to this random number generator's sequence.
		 */
		public def nextAsciiNumber(): Int = {
			randomSeed = (randomSeed * 1103515245 +12345);
			return (Int)(unsigned(randomSeed / 65536) % 128L);
		}

		/**
		 * Convert an Int to an unsigned Int (C-style).
		 */
		static def unsigned(var x: Int): long = {
			return ((long)x & 0x00000000ffffffffL);
		}
	}/*
 *
 * (C) Copyright IBM Corporation 2006
 *
 *  This file is part of X10 Test.
 *
 */
import harness.x10Test;

/**
 * A parallel version of Edmiston's algorithm for sequence alignment, written in X10.
 *
 * This code is an X10 port of the Edmiston_Sequential.c program written by
 * Sirisha Muppavarapu (sirisham@cs.unm.edu), U. New Mexico.
 *
 * @author Vivek Sarkar (vsarkar@us.ibm.com)
 * @author Kemal Ebcioglu (kemal@us.ibm.com)
 *
 * This version splits work across columns of the (N+1)*(M+1)
 * matrix (where N<M), taking advantage of the domain
 * knowledge that only
 * a pre-computation of the preceding 1.5*N columns are
 * necessary, for "warming up" the computation for the current
 * block.
 *
 * Both inter-place and intra-place  parallelism exploited in this version.
 * Intra -place parallelism is achieved through a recursive method and clocks.
 */
public class Edmiston_Parallel10 extends x10Test {

	public boolean run() {
		final Int N = 10; //#rows
		final Int M = 100; //#columns
		final Int EXPECTED_CHECKSUM = -402;
		Random r = new Random(1);
		// Create two random char strings of lengths N and M
		RandCharStr c1 = new RandCharStr(r, N);
		RandCharStr c2 = new RandCharStr(r, M);
		// Create an output matrix for inputs c1 and c2
		EditDistMatrix m = new EditDistMatrix(c1, c2);
		// Print the matrix
		m.printMatrix();
		// Print abstract performance metrics
		m.printMetrics();
		// Verify result against expected.
		m.verify(EXPECTED_CHECKSUM);
		return true;
	}

	public static void main(String[] args) {
		new Edmiston_Parallel10().execute();
	}

	/**
	 * Class implementing data structures and operations for an edit distance matrix.
	 */
	static class EditDistMatrix {
		const Int iGapPen  =  2;
		const Int iMatch  =  -1 ;
		const Int iMisMatch =  1;

		public final Int[.] e; // the edit distance matrix
		final RandCharStr c1; // input string 1
		final RandCharStr c2; // input string 2
		final Int N; // matrix dimensions
		final Int M;

		/**
		 * Constructor method: create the edit distance matrix using Edmiston's algorithm,
		 * from the input strings cSeq1 and cSeq2.
		 */
		public EditDistMatrix(RandCharStr cSeq1, RandCharStr cSeq2) {
			c1 = cSeq1;
			c2 = cSeq2;
			N = c1.s.region.high();
			M = c2.s.region.high();

			final dist(:rank==2) D = (dist(:rank==2)) starBlock([0:N], [0:M]);

			e = new Int[D];

			// compute required number of overlap columns
			// with preceding block
			final Int overlap = ceilFrac(N*(-iMatch), iGapPen)+N;

			// parallel independent computation at each place
			finish ateach (point [p]: distmakeUnique(D.places())) {
				// get sub-distribution for this place
				final dist(:rank==2) myD = D | here;
				// extend it on the left with extra overlap columns
				Int origStartColumn = myD.region.rank(1).low();
				final dist(:rank==2) myExtendedD =
					myD || ([0:N,Math.max(0, origStartColumn-overlap):(origStartColumn-1)]->here);

				// Create a local array including overlap columns
				final Int [.] B = new Int[myExtendedD];

				// Do sequence alignment on local array including the
				// overlap columns. Row 0 and Column 0 are all 0's
				// and do not need to be computed.

				final Int endRow = myExtendedD.region.rank(0).high();
				final Int endColumn = myExtendedD.region.rank(1).high();
				final Int startRow = myExtendedD.region.rank(0).low()+1;
				final Int startColumn = myExtendedD.region.rank(1).low()+1;

				// Recursive method to compute each "wave" in parallel
				finish async {
					final clock c = clock.factory.clock();
					computeRow(B, c, startRow, endRow, startColumn, endColumn);
				}

				// now copy the non-overlap columns to the answer array.
				finish foreach (point [i,j]: myD) e[i,j] = B[i,j];
			}
		}

		/**
		 * In the given current row of matrix B, compute the first element, and
		 * do a barrier sync ("next" on the clock c).
		 * If this is not the last row of B,
		 * recursively spawn the computation for the next row,
		 * registered on the same clock c.
		 * Then, for each remaining element in the current row,
		 * compute the element, and do a barrier sync ("next" on clock c).
		 * Finally the current activity dies,
		 * un-registering itself with the clock c.
		 *
		 * To be called initially with
		 * computeRow(B, c, startRow, endRow, startColumn, endColumn).
		 *
		 * In effect, this recursive method causes the elements of each 'wave'
		 * in the matrix B to be
		 * computed in parallel, with each wave computation followed by
		 * a barrier synchronization:
		 *
		 * 1st wave = { (startRow, startColumn) }
		 *
		 * 2nd wave = { (startRow+1, startColumn), (startRow, startColumn+1) }
		 *
		 * 3rd wave = { (startRow+2, startColumn), (startRow+1, startColumn+1), (startRow, startColumn+2) }
		 *
		 * and so on.
		 */
		void computeRow(final Int[.] B, final clock c, final Int currentRow,
				final Int endRow, final Int startColumn, final Int endColumn) {
			computeElement(B, currentRow, startColumn);
			next;
			if (currentRow < endRow) async clocked(c) computeRow(B, c, currentRow+1, endRow, startColumn, endColumn);
			for (point [currentColumn]: [(startColumn+1):endColumn]) {
				computeElement(B, currentRow, currentColumn);
				next;
			}
		}

		/**
		 * Compute element (i,j) of B, based on its North, West and
		 * Northwest neighbors. All are guaranteed to be at the same place.
		 */
		void computeElement(final Int[.] B, final Int i, final Int j) {
			B[i,j] = min4(0, B[i-1,j]+iGapPen, B[i,j-1]+iGapPen,
					B[i-1,j-1]+
					(c1.s[i] == c2.s[j] ? iMatch : iMisMatch));
		}

		/**
		 * Return a (*,block) distribution for
		 * the region (r1*r2)
		 */
		static dist(:rank==2) starBlock(region(:rank==1) r1, region(:rank==1) r2) {
			dist column2Place = distmakeBlock(r2);
			dist(:rank==2) d = [0:-1,0:-1]->here; // a dist. with empty domain
			for (point [j]: r2) d = d || ([r1,j:j]->column2Place[j]);
			return d;
		}

		/**
		 * Return element i,j of matrix.
		 * This could possibly be a remote read.
		 */
		Int rdElem(final Int i, final Int j) {
			return future(e.dist[i,j]) { e[i,j] }.force();
		}

		/**
		 * Print the Edit Distance Matrix.
		 */
		public void printMatrix()
		{
			System.out.println("Minimum Matrix EditDistance is: " + rdElem(N, M));
			System.out.println("Matrix EditDistance is:");
			System.out.print(pad(' '));
			for (point [j]: [0:M]) System.out.print(pad(c2.s[j]));
			System.out.println();

			for (point [i]: [0:N]) {
				System.out.print(pad(c1.s[i]));
				for (point [j]: [0:M]) System.out.print(pad(rdElem(i, j)));
				System.out.println();
			}
		}

		/**
		 * Print abstract performance metrics
		 */
		void printMetrics() {
			System.out.println("**** START OF ABSTRACT PERFORMANCE METRICS ****");
			System.out.println("e.dist.distEfficiency() = " + e.dist.distEfficiency());
			System.out.println("N = " + N);
			System.out.println("M = " + M);
			System.out.println("nRows = " + e.region.rank(0).size());
			System.out.println("nCols = " + e.region.rank(1).size());
			final Int P = place.MAX_PLACES;
			System.out.println("P = " + P);
			final Int T = min4Count.sum();
			System.out.println("T = " + T);
			final Int X = min4Count.max();
			System.out.println("X = " + X);
			final Int Tpar = Math.max(ceilFrac(T, P), X);
			System.out.println("Tpar = " + Tpar);
			float S = (float) M*N / (float) Tpar;
			System.out.println("S = " + S);
			System.out.println();
			System.out.println("NOTES: 1) These metrics are only valid if your program satisfies the X10 Locality Rule");
			System.out.println("       2) It is recommended that you use -DUMP_STATS_ON_EXIT = true option with metrics");
			System.out.println("       3) In the current performance model, Tpar will always be the same as X.");
			System.out.println("          In a more sophisticated model, X will also include the effect of intra-place activities.");
			System.out.println("**** END OF ABSTRACT PERFORMANCE METRICS ***");
		}

		/**
		 * Verify that the sum of e is equal to the expected value
		 */
		public void verify(Int expectedCheckSum) {
			chk(e.sum() == expectedCheckSum);
		}

		/*
		 * Utility methods.
		 */

		/**
		 * Return ceil(n/m) for positive integers n and m
		 */
		static Int ceilFrac(Int n, Int m) {
			return (n+m-1)/m;
		}

		final Int[.] min4Count = new Int[distmakeUnique()]; // Array to support counting of MIN4 operations.

		/**
		 * returns the minimum of 4 integers.
		 */
		Int min4(Int w, Int x, Int y, Int z) {
			final place myP = here;
			finish async(myP) atomic min4Count[(myP).id] += 1;
			return Math.min(Math.min(w, x), Math.min(y, z));
		}

		/**
		 * pad() methods for different data types
		 * Output string = input value converted to a string of length >= 3, with a blank inserted at the start and end.
		 */
		static String pad(Int x) { return pad(x + ""); }
		static String pad(char x) { return pad(x + ""); }
		static String pad(String s) {
			final Int n = 3;
			while (s.length() < n) s = " "+s;
			return " "+s+" ";
		}
	}

	/**
	 * Common random number generator class.
	 */
	static class Random {

		Int randomSeed;

		/**
		 * Create a new random number generator with seed x
		 */
		public Random(Int x) {
			randomSeed = x;
		}

		/**
		 * Returns the next random number between 0 and 128,
		 * according to this random number generator's sequence.
		 */
		public Int nextAsciiNumber() {
			randomSeed = (randomSeed * 1103515245 +12345);
			return (Int)(unsigned(randomSeed / 65536) % 128L);
		}

		/**
		 * Convert an Int to an unsigned Int (C-style).
		 */
		static long unsigned(Int x) {
			return ((long)x & 0x00000000ffffffffL);
		}
	}

	/**
	 * A class pertaining to random character arrays (strings).
	 */
	static value class RandCharStr {.{.{*
 *
 * (C) Copyright IBM Corporation 2006
 *
 *  This file is part of X10 Test.
 *
 */
import harness.x10Test;

/**
 * A parallel version of Edmiston's algorithm for sequence alignment, written in X10.
 *
 * This code is an X10 port of the Edmiston_Sequential.c program written by
 * Sirisha Muppavarapu (sirisham@cs.unm.edu), U. New Mexico.
 *
 * @author Vivek Sarkar (vsarkar@us.ibm.com)
 * @author Kemal Ebcioglu (kemal@us.ibm.com)
 *
 * This version splits work across columns of the (N+1)*(M+1)
 * matrix (where N<M), taking advantage of the domain
 * knowledge that only
 * a pre-computation of the preceding 1.5*N columns are
 * necessary, for "warming up" the computation for the current
 * block.
 *
 * Both inter-place and intra-place  parallelism exploited in this version.
 * Intra -place parallelism is achieved through a recursive method and clocks.
 */
public class Edmiston_Parallel10 extends x10Test {

	public boolean run() {
		final Int N = 10; //#rows
		final Int M = 100; //#columns
		final Int EXPECTED_CHECKSUM = -402;
		Random r = new Random(1);
		// Create two random char strings of lengths N and M
		RandCharStr c1 = new RandCharStr(r, N);
		RandCharStr c2 = new RandCharStr(r, M);
		// Create an output matrix for inputs c1 and c2
		EditDistMatrix m = new EditDistMatrix(c1, c2);
		// Print the matrix
		m.printMatrix();
		// Print abstract performance metrics
		m.printMetrics();
		// Verify result against expected.
		m.verify(EXPECTED_CHECKSUM);
		return true;
	}

	public static void main(String[] args) {
		new Edmiston_Parallel10().execute();
	}

	/**
	 * Class implementing data structures and operations for an edit distance matrix.
	 */
	static class EditDistMatrix {
		const Int iGapPen  =  2;
		const Int iMatch  =  -1 ;
		const Int iMisMatch =  1;

		public final Int[.] e; // the edit distance matrix
		final RandCharStr c1; // input string 1
		final RandCharStr c2; // input string 2
		final Int N; // matrix dimensions
		final Int M;

		/**
		 * Constructor method: create the edit distance matrix using Edmiston's algorithm,
		 * from the input strings cSeq1 and cSeq2.
		 */
		public EditDistMatrix(RandCharStr cSeq1, RandCharStr cSeq2) {
			c1 = cSeq1;
			c2 = cSeq2;
			N = c1.s.region.high();
			M = c2.s.region.high();

			final dist(:rank==2) D = (dist(:rank==2)) starBlock([0:N], [0:M]);

			e = new Int[D];

			// compute required number of overlap columns
			// with preceding block
			final Int overlap = ceilFrac(N*(-iMatch), iGapPen)+N;

			// parallel independent computation at each place
			finish ateach (point [p]: distmakeUnique(D.places())) {
				// get sub-distribution for this place
				final dist(:rank==2) myD = D | here;
				// extend it on the left with extra overlap columns
				Int origStartColumn = myD.region.rank(1).low();
				final dist(:rank==2) myExtendedD =
					myD || ([0:N,Math.max(0, origStartColumn-overlap):(origStartColumn-1)]->here);

				// Create a local array including overlap columns
				final Int [.] B = new Int[myExtendedD];

				// Do sequence alignment on local array including the
				// overlap columns. Row 0 and Column 0 are all 0's
				// and do not need to be computed.

				final Int endRow = myExtendedD.region.rank(0).high();
				final Int endColumn = myExtendedD.region.rank(1).high();
				final Int startRow = myExtendedD.region.rank(0).low()+1;
				final Int startColumn = myExtendedD.region.rank(1).low()+1;

				// Recursive method to compute each "wave" in parallel
				finish async {
					final clock c = clock.factory.clock();
					computeRow(B, c, startRow, endRow, startColumn, endColumn);
				}

				// now copy the non-overlap columns to the answer array.
				finish foreach (point [i,j]: myD) e[i,j] = B[i,j];
			}
		}

		/**
		 * In the given current row of matrix B, compute the first element, and
		 * do a barrier sync ("next" on the clock c).
		 * If this is not the last row of B,
		 * recursively spawn the computation for the next row,
		 * registered on the same clock c.
		 * Then, for each remaining element in the current row,
		 * compute the element, and do a barrier sync ("next" on clock c).
		 * Finally the current activity dies,
		 * un-registering itself with the clock c.
		 *
		 * To be called initially with
		 * computeRow(B, c, startRow, endRow, startColumn, endColumn).
		 *
		 * In effect, this recursive method causes the elements of each 'wave'
		 * in the matrix B to be
		 * computed in parallel, with each wave computation followed by
		 * a barrier synchronization:
		 *
		 * 1st wave = { (startRow, startColumn) }
		 *
		 * 2nd wave = { (startRow+1, startColumn), (startRow, startColumn+1) }
		 *
		 * 3rd wave = { (startRow+2, startColumn), (startRow+1, startColumn+1), (startRow, startColumn+2) }
		 *
		 * and so on.
		 */
		void computeRow(final Int[.] B, final clock c, final Int currentRow,
				final Int endRow, final Int startColumn, final Int endColumn) {
			computeElement(B, currentRow, startColumn);
			next;
			if (currentRow < endRow) async clocked(c) computeRow(B, c, currentRow+1, endRow, startColumn, endColumn);
			for (point [currentColumn]: [(startColumn+1):endColumn]) {
				computeElement(B, currentRow, currentColumn);
				next;
			}
		}

		/**
		 * Compute element (i,j) of B, based on its North, West and
		 * Northwest neighbors. All are guaranteed to be at the same place.
		 */
		void computeElement(final Int[.] B, final Int i, final Int j) {
			B[i,j] = min4(0, B[i-1,j]+iGapPen, B[i,j-1]+iGapPen,
					B[i-1,j-1]+
					(c1.s[i] == c2.s[j] ? iMatch : iMisMatch));
		}

		/**
		 * Return a (*,block) distribution for
		 * the region (r1*r2)
		 */
		static dist(:rank==2) starBlock(region(:rank==1) r1, region(:rank==1) r2) {
			dist column2Place = distmakeBlock(r2);
			dist(:rank==2) d = [0:-1,0:-1]->here; // a dist. with empty domain
			for (point [j]: r2) d = d || ([r1,j:j]->column2Place[j]);
			return d;
		}

		/**
		 * Return element i,j of matrix.
		 * This could possibly be a remote read.
		 */
		Int rdElem(final Int i, final Int j) {
			return future(e.dist[i,j]) { e[i,j] }.force();
		}

		/**
		 * Print the Edit Distance Matrix.
		 */
		public void printMatrix()
		{
			System.out.println("Minimum Matrix EditDistance is: " + rdElem(N, M));
			System.out.println("Matrix EditDistance is:");
			System.out.print(pad(' '));
			for (point [j]: [0:M]) System.out.print(pad(c2.s[j]));
			System.out.println();

			for (point [i]: [0:N]) {
				System.out.print(pad(c1.s[i]));
				for (point [j]: [0:M]) System.out.print(pad(rdElem(i, j)));
				System.out.println();
			}
		}

		/**
		 * Print abstract performance metrics
		 */
		void printMetrics() {
			System.out.println("**** START OF ABSTRACT PERFORMANCE METRICS ****");
			System.out.println("e.dist.distEfficiency() = " + e.dist.distEfficiency());
			System.out.println("N = " + N);
			System.out.println("M = " + M);
			System.out.println("nRows = " + e.region.rank(0).size());
			System.out.println("nCols = " + e.region.rank(1).size());
			final Int P = place.MAX_PLACES;
			System.out.println("P = " + P);
			final Int T = min4Count.sum();
			System.out.println("T = " + T);
			final Int X = min4Count.max();
			System.out.println("X = " + X);
			final Int Tpar = Math.max(ceilFrac(T, P), X);
			System.out.println("Tpar = " + Tpar);
			float S = (float) M*N / (float) Tpar;
			System.out.println("S = " + S);
			System.out.println();
			System.out.println("NOTES: 1) These metrics are only valid if your program satisfies the X10 Locality Rule");
			System.out.println("       2) It is recommended that you use -DUMP_STATS_ON_EXIT = true option with metrics");
			System.out.println("       3) In the current performance model, Tpar will always be the same as X.");
			System.out.println("          In a more sophisticated model, X will also include the effect of intra-place activities.");
			System.out.println("**** END OF ABSTRACT PERFORMANCE METRICS ***");
		}

		/**
		 * Verify that the sum of e is equal to the expected value
		 */
		public void verify(Int expectedCheckSum) {
			chk(e.sum() == expectedCheckSum);
		}

		/*
		 * Utility methods.
		 */

		/**
		 * Return ceil(n/m) for positive integers n and m
		 */
		static Int ceilFrac(Int n, Int m) {
			return (n+m-1)/m;
		}

		final Int[.] min4Count = new Int[distmakeUnique()]; // Array to support counting of MIN4 operations.

		/**
		 * returns the minimum of 4 integers.
		 */
		Int min4(Int w, Int x, Int y, Int z) {
			final place myP = here;
			finish async(myP) atomic min4Count[(myP).id] += 1;
			return Math.min(Math.min(w, x), Math.min(y, z));
		}

		/**
		 * pad() methods for different data types
		 * Output string = input value converted to a string of length >= 3, with a blank inserted at the start and end.
		 */
		static String pad(Int x) { return pad(x + ""); }
		static String pad(char x) { return pad(x + ""); }
		static String pad(String s) {
			final Int n = 3;
			while (s.length() < n) s = " "+s;
			return " "+s+" ";
		}
	}

	/**
	 * Common random number generator class.
	 */
	static class Random {

		Int randomSeed;

		/**
		 * Create a new random number generator with seed x
		 */
		public Random(Int x) {
			randomSeed = x;
		}

		/**
		 * Returns the next random number between 0 and 128,
		 * according to this random number generator's sequence.
		 */
		public Int nextAsciiNumber() {
			randomSeed = (randomSeed * 1103515245 +12345);
			return (Int)(unsigned(randomSeed / 65536) % 128L);
		}

		/**
		 * Convert an Int to an unsigned Int (C-style).
		 */
		static long unsigned(Int x) {
			return ((long)x & 0x00000000ffffffffL);
		}
	}

	/**
	 * A class pertaining to random character arrays (strings).
	 */
	static value class RandCharStr {
		public val s: Array[char]; // the string (character array).

		/**
		 * Create a random character array of
		 * length len from the alphabet A,C,G,T,
		 * using the random number generator r.
		 * The array begins with an extra '-',
		 * thus it will have len+1 characters.
		 */
		public def this(var r: Random, var len: Int): RandCharStr = {
			final val s1: Array[char] = new Array[char](len+1);
			s1(0) =  '-';
			var i: Int = 1;
			while (i <= len) {
				var x: Int = r.nextAsciiNumber();
				switch (x) {
					case 65:case 65: s1(i++) = 'A';  break;
					case 67:case 67: s1(i++) = 'C';  break;
					case 71:case 71: s1(i++) = 'G';  break;
					case 84:case 84: s1(i++) = 'T';  break;
					default:
				}
			}
			s = new Array[char](Dist.makeConstant([0..len], here), (var point [i]: point): char => { return s1(i); });
		}
	}
}
