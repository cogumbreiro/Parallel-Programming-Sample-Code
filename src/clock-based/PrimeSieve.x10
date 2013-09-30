public class PrimeSieve {
    static public def main(args:Array[String](1)):void {
        val N:Int = Int.parse(args(0));
        val total:Int;

        var clock:Clock;
        val dbuffer = new Array[Int](2,0);
        async (clock) {
            // initially assume all integers are prime
            val isPrime = new Array[Boolean](N + 1);
            for (i in 2..N) {
                isPrime(i) = true;
            }
            var even = true;
            // mark non-primes <= N using Sieve of Eratosthenes
            for (var i:Int = 2; i*i <= N; i++) {

                // if i is prime, then mark multiples of i as nonprime
                // suffices to consider mutiples i, i+1, ..., N/i
                if (isPrime(i)) {
                    for (var j:Int = i; i*j <= N; j++) {
                        isPrime(i*j) = false;
                    }
                    if (even)
                        dbuffer(0) = i;
                    else
                        dbuffer(1) = i;
                    clock.advance();
                }
            }
        }
        async clocked(clock) {
        // count primes
        var primes:Int = 0;
        for (i in 2..N) {
            if (isPrime(i)) primes++;
        }
        }
        Console.OUT.println(primes);
    }
}

