public class ArtInfo {
    public static void main(String[] a) throws Exception {
        Runtime r = Runtime.getRuntime();
        System.out.println("maxMemory   = " + (r.maxMemory() >> 20) + " MiB");
        System.out.println("totalMemory = " + (r.totalMemory() >> 20) + " MiB");
        System.out.println("vm          = " + System.getProperty("java.vm.version"));
    }
}
