public class Fact {
    def this() {}
	
    def fact(n:long):long = n < 2L ? 1L : n*fact(n-1);

    public static def main(args:Array[String](1)) {
        if (args.size == 0) {
            Console.OUT.println("Sorry. Run fib <n:int>");
            return;
        }
        val n = Int.parseInt(args(0));
        val f = new Fib();
		
        for (var i:Int=2; i <= n; i++) {
            val fib = f.fib(i);
            val afib = f.afib(i);
            Console.OUT.print("fib(" + i + ")= " + fib );
            Console.OUT.println(fib == afib ? "(ok)" : " afib = " + afib);
        }
    }
}
