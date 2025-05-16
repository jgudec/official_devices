\- Enable SecureNFC support for relevant variants.  
\- Remove debugfs references in init scripts.  
\- Optimize native executables for Cortex-A76 CPU.  
\- Don't latch unsignaled buffers to reduce jank frames.  
\- Tune UCLAMP_MIN range and RT task defaults.  
\- Disable OMX as it is deprecated.  
\- Disable MTK SecureElement service for non-NFC devices.  
\- Update blobs to U1TDS34.94-12-9-10-2.  
\- Update AVB rollback index to U1TDS34.94-12-9-10-2.  
\- Don't avb chain boot partition as BL expects boot props to be in vbmeta.  
\- Move to OSS libfmjni.  
\- Pin modified scripts to remove FTS support.  
\- Drop dolby to alleviate audio distortion.  
\- Add support for IPSEC_TUNNEL_MIGRATION.  
\- Allow PinnerService to pin launcher and webview to improve interactivity.  
\- Drop redundant cancunn/devonn WMT configurations.  
\- Add support for Android 14 January SPL firmware. (U1TDS34.94-12-9-10-2)  
\- Ship gpueb.img from U1TDS34.94-12-9-10-2 to retain backwards compatibility with older firmware.  
\- Improve audio quality by reducing distortion.  
\- Fix NFC for SKU n. (XT2343-1, Samsung NFC)  
\- Kernel state at r1b3.  
\- Remove unused oem services as we don't ship the debugging blobs that are required by them.  
\- Remove runtime ro.carrier setting as it is set at build time.  
\- Remove init.mmi.chipset.rc as there is no need for a separate rc file for a simple insmod.  
\- Drop batt_health completely as it is unused on AOSP.  
\- Move init.cancunf.sku.rc to vendor/etc/init to follow the hierarchy of cpu/soc/device-specific init configurations.  
\- Override AIDL NXP eSE vintf for non-NXP devices to silence eSE logspam on non-NFC devices.  
\- Switch to AOSP's default UI renderengine.  
\- Fix random Wi-Fi disconnections in 2.4GHz networks by increasing the maximum bandwidth to 40MHz.  
\- Drop ATCI service as it is useless.  
\- Enable hide cutout emulations for full screen within games.  

Learn more at [blog.pixelos.net](https://blog.pixelos.net/)