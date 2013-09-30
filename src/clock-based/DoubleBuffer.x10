public class DoubleBuffer[T](clock:Clock) {
    var isEven = true;
    val buffer:Array[T];
    
    def operator this(T value) {
        if (isEven) {
            buffer(0) = value;
        } else {
            buffer(1) = value;
        }
        isEven = !isEven;
    }
}
