public class IterAveraging3 {
    public static def main(args: Rail[String])  {
        Console.OUT.println(part);
        val buff1 = new Array[Float](10, (x:Int) => x + 1f);
        val buff2 = new Array[Float](10);
        
        val buff = [
            buff1,
            buff2
        ];
        
        val N = buff(0).size;
        val T = 4;
        val part = N / T;
        Console.OUT.println(part);
        val I = 1000000;
        
        var oldBuff:Int = 0; // mutable variables need a type
        var newBuff:Int = 1; // mutable variables need a type
        
        finish {
            val c = Clock.Make();
            for (t in 0..(T-1)) async(c) {
                for (i in 1..I) {
                    for (idx in (t * part) ..((t + 1) * part - 1)) {
                        val l = (idx + 1) % N;
                        val r = (idx + N - 1) % N;
                        buff(newBuff)(idx) = (buff(oldBuff)(l) + buff(oldBuff)(r)) / 2;
                    }
                    val temp = oldBuff; oldBuff = newBuff; newBuff = temp;
                    Console.OUT.println(t);
                    Console.OUT.println(buff(newBuff));
                    Clock.advanceAll();
                }
            }
            c.drop();
        }
        Console.OUT.println(buff(oldBuff));
    }
}
