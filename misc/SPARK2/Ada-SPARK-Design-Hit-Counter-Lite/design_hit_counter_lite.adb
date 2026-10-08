pragma Ada_2022;
package body Design_Hit_Counter_Lite with SPARK_Mode => On is
   function Empty return Counter is
   begin return (Bucket_Hits => (others => 0)); end Empty;
   procedure Hit (C : in out Counter; B : Bucket) is
   begin if C.Bucket_Hits (B) < Bucket_Capacity then C.Bucket_Hits (B) := C.Bucket_Hits (B) + 1; end if; end Hit;
   function Read (C : Counter; B : Bucket) return Hits is
   begin return C.Bucket_Hits (B); end Read;
   function Total (C : Counter) return Natural is
   begin return C.Bucket_Hits (1) + C.Bucket_Hits (2) + C.Bucket_Hits (3) + C.Bucket_Hits (4); end Total;
end Design_Hit_Counter_Lite;
