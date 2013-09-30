public class DoubleBufferReader[T](buffer:Array[T]{size == 2}, clock:Clock) implements () => T  {
    var isEven:Boolean = true;
    
    public operator this():T {
        return get();
    }
    
    public def get():T {
        clock.advance();
        val result = buffer(isEven ? 0 : 1);
        isEven = !isEven;
        return result;
    }
}
