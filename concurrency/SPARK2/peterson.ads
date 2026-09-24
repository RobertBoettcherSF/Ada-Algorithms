pragma SPARK_Mode (On);
package Peterson is
   type Process_Id is (First, Second);
   type Flags is array (Process_Id) of Boolean;
   type State is record Want : Flags := (others => False); Turn : Process_Id := First; end record;
   procedure Request_Entry (S : in out State; P : Process_Id);
   function Can_Enter (S : State; P : Process_Id) return Boolean;
   procedure Leave (S : in out State; P : Process_Id);
end Peterson;
