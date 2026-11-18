package com.follow.clash.core.mobile;

/** Callback used by the Rust core to deliver method results and events. */
public interface ResultHandler {
    void onResult(byte[] data);
}
