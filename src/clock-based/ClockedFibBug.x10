public class ClockedFib implements (Int) => ULong {
    public operator this(n:Int) {
        val N:Long = s.size > 0 as Long ? Long.parse(s(0)) : 1000 as Long;
        finish async {
<<<<<<< HEAD:src/clock-based/ClockedFibBug.x10
            val x = new Clocked[Long](1);
            val y = new Clocked[Long](1);
            //val f = Clock.make();
            async clocked(x.clock, y.clock/*, f*/) {
=======
            val x = new Clocked[Long](1, Clock.make("x"));
            val y = new Clocked[Long](1, Clock.make("y"));
            val f = Clock.make("f");
            async clocked(x.clock, y.clock, f) {
>>>>>>> 91568dbda05dfd902e0270d3dc870198e2664856:src/ClockedFib.x10
                while (y() < N) {
                    x() = x() + y();
                    y.next();
                    x.next();
                }
                x() = (Long.MAX_VALUE);
            }
            async clocked(x.clock, y.clock/*, f*/) {
                while (x() < N) {
                    y() = x();
                    Console.OUT.print(" " +  x());
                    y.next();
                    x.next();
                    // f.advance(); introduce a deadlock
                }
                y() = (Long.MAX_VALUE);
                Console.OUT.println();
            }
<<<<<<< HEAD:src/clock-based/ClockedFibBug.x10
            /*
            x.drop();
            y.drop();
            f.advance(); // wait for the other two tasks
            Console.OUT.println(x.clock.phase());
            Console.OUT.println(y.clock.phase());*/
=======
            x.clock.drop();
            y.clock.drop();
            f.advance(); // wait for the other two tasks to finish
            //Console.OUT.println(x.clock.phase());
            //Console.OUT.println(y.clock.phase());
>>>>>>> 91568dbda05dfd902e0270d3dc870198e2664856:src/ClockedFib.x10
        }
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
        val f = new ClockedFib();
        Console.OUT.println(f(n));
    }
}
