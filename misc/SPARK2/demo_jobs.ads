pragma Ada_2022;

--  Concrete jobs registered for the educational sheet.
--  Workers dispatch Job_Kind to these procedures (no access-to-subprogram).
package Demo_Jobs
  with SPARK_Mode => On
is
   procedure Reset
     with Global => null;

   procedure Increment_Counter (Delta_Value : Integer)
     with Global => null,
          Pre    => Delta_Value in -1000 .. 1000;

   function Counter_Value return Integer
     with Global => null;

   --  Puts Arg on Channel.PO then Gets it back (round-trip ping).
   procedure Ping_Channel (Arg : Integer)
     with Global => null;

   function Last_Ping return Integer
     with Global => null;

end Demo_Jobs;
