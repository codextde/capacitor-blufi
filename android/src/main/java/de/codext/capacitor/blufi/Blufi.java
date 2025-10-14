package de.codext.capacitor.blufi;

import com.getcapacitor.Logger;

public class Blufi {

    public String echo(String value) {
        Logger.info("Echo", value);
        return value;
    }
}
