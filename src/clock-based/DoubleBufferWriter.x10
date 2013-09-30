public class DoubleBufferWriter[T](buffer:Array[T]{size == 2}, clock:Clock) {
    private var isEven:Boolean = true;
    
    public def set(value:T) {
        buffer(isEven ? 0 : 1) = value;
        isEven = !isEven;
        clock.advance();
    }
    
    public operator this() = (value:T) {
        set(value);
    }
}
