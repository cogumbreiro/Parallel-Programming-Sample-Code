public class ClockedFib {
    public static def main(s:Array[String](1)) {
        val N:Long = s.size > 0 as Long ? Long.parse(s(0)) : 1000 as Long;
        Console.OUT.println("Started!");
        finish async {
            val x = new Clocked[Long](1);
            val y = new Clocked[Long](1);
            val f = Clock.make();
            async clocked(x.clock, y.clock, f) {
                while (y() < N) {
                    x() = x() + y();
                    y.next();
                    x.next();
                }
                x() = (Long.MAX_VALUE);
            }
            async clocked(x.clock, y.clock, f) {
                while (x() < N) {
                    y() = x();
                    Console.OUT.print(" " +  x());
                    y.next();
                    x.next();
                    
                }
                y() = (Long.MAX_VALUE);
                Console.OUT.println();
            }
            x.drop();
            y.drop();
            f.advance(); // wait for the other two tasks
            Console.OUT.println(x.clock.phase());
            Console.OUT.println(y.clock.phase());
        }
    }
}
