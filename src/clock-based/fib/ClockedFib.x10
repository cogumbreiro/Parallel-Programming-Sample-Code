public class ClockedFib implements (Int) => ULong {
    public operator this(n:Int) {
        val result : ULong;
        finish async {
            val x = new Clocked[ULong](1);
            val y = new Clocked[ULong](1);
            async clocked(x.clock, y.clock) {
                for (i in 2..n) {
                    x() = x() + y();
                    y.next();
                    x.next();
                }
                x() = (ULong.MAX_VALUE);
            }
            async clocked(x.clock, y.clock) {
                for (i in 2..n) {
                    y() = x();
                    y.next();
                    x.next();
                    
                }
                result = x();
                y() = (ULong.MAX_VALUE);
            }
        }
        return result;
    }
    
    public static def main(args:Array[String](1)) {
        if (args.size == 0) {
            Console.OUT.println("Sorry. Run fib <n:int>");
            return;
        }
        val n = Int.parse(args(0));
        if (n > 300 as Int) {
            Console.OUT.println("Number must be smaller than 301.");
            return;
        }
        val f = new ClockedFib();
        Console.OUT.println(f(n));
    }
}
