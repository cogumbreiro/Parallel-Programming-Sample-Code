class Data {
    public static val buff1 = new Array[Float](100, (x:Int) => x + 1f);
    public static val buff2 = new Array[Float](100);
    
    public static val buff = [
        buff1,
        buff2
    ];
    
    public static val N = buff(0).size;
    public static val T = 2;
    public static val PART = N / T;
    public static val I = 10000;
}
