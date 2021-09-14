// Baseado em https://stackoverflow.com/a/52565585
// Classe que faz o parse de tamanhos expressos em formato Humano
// e retorna o equivalente em LONG para ser usado em alocação de disco / memória
public class ConversionUtil {

    public static String units = "BKMGTPEZY";

    public static int indexOf(String pattern, String s) {
        def matcher = s =~ pattern;
        return matcher.find() ? matcher.start() : -1;
    }

    public static long parseAny(String arg0)
    {
        int index = indexOf("[A-Za-z]", arg0);
        double ret = Double.parseDouble(arg0.substring(0, index));
        String unitString = arg0.substring(index);
        int unitChar = unitString.charAt(0);
        int power = units.indexOf(unitChar);
        boolean isSi = unitString.indexOf('i')!=-1;
        int factor = 1000;
        if (isSi)
        {
            factor = 1024;
        }
        return new Double(ret * Math.pow(factor, power)).longValue();
    }

    public static void main(String[] args) {
        System.out.println(parseAny("300.00 GiB")); // requires a space
        System.out.println(parseAny("300.00 GB"));
        System.out.println(parseAny("300.00 B"));
        System.out.println(parseAny("300 EB"));
        System.out.println(parseAny("300.00 GiB"));
        System.out.println(parseAny("300M"));
    }
}
