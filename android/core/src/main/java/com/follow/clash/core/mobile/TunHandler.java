package com.follow.clash.core.mobile;

/** TUN callbacks the host provides to the core. */
public interface TunHandler {
    boolean protect(int fd);
    int resolveUid(int protocol, String source, String target);
    String resolvePackage(int uid);
}
