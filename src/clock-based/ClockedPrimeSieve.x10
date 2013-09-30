public class ClockedPrimeSieve {
    static public def main(args:Array[String](1)):void {
        val N:Int = Int.parse(args(0));
        val total:Int;
        finish async {
            val clock = Clock.make();
            val dbuffer = new Array[Int](2,0);
            
            async clocked(clock) {
                val writer = new DoubleBufferWriter[Int](dbuffer, clock);
                // initially assume all integers are prime
                val isPrime = new Array[Boolean](N + 1);
                for (i in 2..N) {
                    isPrime(i) = true;
                }
                // mark non-primes <= N using Sieve of Eratosthenes
                for (var i:Int = 2; i*i <= N; i++) {

                    // if i is prime, then mark multiples of i as nonprime
                    // suffices to consider mutiples i, i+1, ..., N/i
                    if (isPrime(i)) {
                        for (var j:Int = i; i*j <= N; j++) {
                            isPrime(i*j) = false;
                        }
                        writer() = i;
                    }
                }
                writer() = -1;
            }
            
            async clocked(clock) {
                // count primes
                var primes:Int = 0;
                val reader = new DoubleBufferReader[Int](dbuffer, clock);
                while(reader() > 0) {
                    primes++;
                }
                total = primes;
            }
        }
        Console.OUT.println(total);
    }
}

