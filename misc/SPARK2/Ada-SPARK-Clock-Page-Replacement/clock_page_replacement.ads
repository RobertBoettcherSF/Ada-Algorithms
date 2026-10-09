pragma SPARK_Mode (On);
package Clock_Page_Replacement is
   Capacity : constant := 4;
   subtype Frame_Id is Positive range 1 .. Capacity;
   subtype Page is Natural range 0 .. 100;
   type Frame is record Value : Page := 0; Referenced : Boolean := False; Used : Boolean := False; end record;
   type Frames is array (Frame_Id) of Frame;
   subtype Fault_Count_Type is Natural;
   type State is record
      Slots : Frames := (others => (Value => 0, Referenced => False, Used => False));
      Hand : Frame_Id := Frame_Id'First;
      Faults : Fault_Count_Type := 0;
   end record;
   --  Every access to a page not in a frame is one fault; the caller keeps
   --  the count below Natural'Last (no silent saturation).
   procedure Access_Page (S : in out State; P : Page)
     with Pre => S.Faults < Fault_Count_Type'Last;
   function Fault_Count (S : State) return Natural;
end Clock_Page_Replacement;
