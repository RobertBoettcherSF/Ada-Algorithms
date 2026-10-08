pragma SPARK_Mode (On);
package Bakery is
   Max_Processes : constant := 4;
   subtype Process_Id is Positive range 1 .. Max_Processes;
   subtype Ticket is Natural range 0 .. Max_Processes * 2;
   type Ticket_Array is array (Process_Id) of Ticket;
   type Flag_Array is array (Process_Id) of Boolean;
   type State is record Choosing : Flag_Array := (others => False); Number : Ticket_Array := (others => 0); end record;
   procedure Take_Number (S : in out State; P : Process_Id);
   function Before (S : State; Left, Right : Process_Id) return Boolean;
   function Can_Enter (S : State; P : Process_Id) return Boolean;
   procedure Leave (S : in out State; P : Process_Id);
end Bakery;
