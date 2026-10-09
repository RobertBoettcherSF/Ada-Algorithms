--  PLACEHOLDER: bounded stub (the folder name ends in -Stub), not a full Logger-Rate-Limiter implementation; see PROOFS.csv stub
pragma SPARK_Mode (On);

package Logger_Rate_Limiter_Stub is
   subtype Timestamp is Integer range 0 .. 1000;
   subtype Cooldown is Integer range 0 .. 1000;

   function Allowed
     (Last_Message : Timestamp; Now : Timestamp; Interval : Cooldown)
      return Boolean with Global => null, Pre => Now >= Last_Message;
end Logger_Rate_Limiter_Stub;
