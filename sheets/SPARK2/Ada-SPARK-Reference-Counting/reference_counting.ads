pragma SPARK_Mode (On);
package Reference_Counting is
   Max_Objects : constant := 8;
   subtype Object_Id is Positive range 1 .. Max_Objects;
   subtype Count is Natural range 0 .. 10;
   type Counts is array (Object_Id) of Count;
   type Live_Bits is array (Object_Id) of Boolean;
   type State is record Live : Live_Bits := (others => False); Refs : Counts := (others => 0); end record;
   procedure Create (S : in out State; O : Object_Id);
   procedure Add_Reference (S : in out State; O : Object_Id);
   procedure Release (S : in out State; O : Object_Id);
   function Reference_Count (S : State; O : Object_Id) return Count;
end Reference_Counting;
