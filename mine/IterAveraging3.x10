public class IterAveraging3 {
    public static def main(args: Rail[String])  {
        clocked finish {
            for (t in 0..(Data.T-1)) clocked async {
                var oldBuff:Int = 0; // private variables, or race condition! 
                var newBuff:Int = 1; 
                for (i in 1..Data.I) {
                    for (idx in (t * Data.PART) ..((t + 1) * Data.PART - 1)) {
                        val l = (idx + Data.N - 1) % Data.N;
                        val r = (idx + 1) % Data.N;
                        Data.buff(newBuff)(idx) = (Data.buff(oldBuff)(l) + Data.buff(oldBuff)(r)) / 2f;
                    }
                    val temp = oldBuff; oldBuff = newBuff; newBuff = temp;
                    Clock.advanceAll();
                }
            }
        }
        Console.OUT.println(Data.buff(1));
    }
}
