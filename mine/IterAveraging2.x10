public class IterAveraging2 {
    public static def main(args: Rail[String])  {
        var oldBuff:Int = 0; // mutable variables need a type
        var newBuff:Int = 1; // mutable variables need a type
        for (i in 1..Data.I) {
            finish for (idx in 0..(Data.N - 1)) async {
                val l = (idx + Data.N - 1) % Data.N;
                val r = (idx + 1) % Data.N;
                Data.buff(newBuff)(idx) = (Data.buff(oldBuff)(l) + Data.buff(oldBuff)(r)) / 2;
            }
            val temp = oldBuff; oldBuff = newBuff; newBuff = temp;
        }
        Console.OUT.println(Data.buff(1));
    }
}
