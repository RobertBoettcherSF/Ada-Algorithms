pragma SPARK_Mode (On);
package Clock_Page_Replacement is
   Capacity : constant := 4;
   subtype Frame_Id is Positive range 1 .. Capacity;
   subtype Page is Natural range 0 .. 100;
   type Frame is record Value : Page := 0; Referenced : Boolean := False; Used : Boolean := False; end record;
   type Frames is array (Frame_Id) of Frame;
   subtype Fault_Count_Type is Natural range 0 .. 100;
   type State is record
      Slots : Frames := (others => (Value => 0, Referenced => False, Used => False));
      Hand : Frame_Id := Frame_Id'First;
      Faults : Fault_Count_Type := 0;
   end record;
   procedure Access_Page (S : in out State; P : Page);
   function Fault_Count (S : State) return Natural;
end Clock_Page_Replacement;
