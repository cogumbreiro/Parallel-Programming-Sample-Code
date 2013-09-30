public class IterFib implements (Int) => ULong {
    public operator this(n:Int):ULong = {
        var x:ULong=0, y:ULong=1;
        for (var i:Long=2; i <= n; i++) {
            val t = x+y;
            x=y;
            y=t;
        }
        return y;
    }

    public static def main(args:Array[String](1)) {
        if (args.size == 0) {
            Console.OUT.println("Sorry. Run fib <n:int>");
            return;
        }
        val n = Int.parseInt(args(0));
        if (n > 300) {
            Console.OUT.println("Number must be smaller than 301.");
            return;
        }
        val f = new IterFib();
        Console.OUT.println(f(n));
    }
}
