pragma Ada_2022;
package Word_Break_Stub with SPARK_Mode => On is
   subtype Position is Positive range 1 .. 6;
   type Letters is array (Position) of Boolean;
   function Can_Break (Text : Letters) return Boolean with Global => null;
end Word_Break_Stub;
