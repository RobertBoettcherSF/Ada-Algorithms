pragma Ada_2022;
package body Delta_Encoding with SPARK_Mode => On is
   function Net_Delta (Input : Sample_Array) return Integer is
   begin
      return Integer (Input (Input'Last)) - Integer (Input (Input'First));
   end Net_Delta;
end Delta_Encoding;
