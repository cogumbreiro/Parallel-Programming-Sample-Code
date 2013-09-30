public class RecFib implements (Int) => ULong {
    public operator this(n:Int):ULong = n < 2 ? n as ULong : this(n-1)+this(n-2);
    
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
        val f = new RecFib();
        Console.OUT.println(f(n));
    }
}
