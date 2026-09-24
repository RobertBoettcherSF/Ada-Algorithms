pragma SPARK_Mode (On);

--  Host↔device transfer accountant (educational).
--  No proprietary PCIe / vendor headers — abstract sizes only.

package PCIe_Transfer_Model is

   Max_Transfer_Bytes : constant := 4096;
   Max_Total_Bytes    : constant := 65_536;
   Default_Align      : constant := 64;
   Default_Budget     : constant := 2048;

   subtype Byte_Count is Natural range 0 .. Max_Total_Bytes;
   subtype Transfer_Size is Positive range 1 .. Max_Transfer_Bytes;
   subtype Align_Value is Positive range 1 .. 256;
   subtype Budget_Value is Positive range 1 .. Max_Transfer_Bytes;

   type Direction is (H2D, D2H);

   type Model is private;

   function Total_Bytes (M : Model) return Byte_Count
     with Global => null;

   function Total_H2D (M : Model) return Byte_Count
     with Global => null;

   function Total_D2H (M : Model) return Byte_Count
     with Global => null;

   function Used_This_Tick (M : Model) return Byte_Count
     with Global => null;

   function Budget (M : Model) return Budget_Value
     with Global => null;

   function Create
     (Budget_Per_Tick : Budget_Value := Default_Budget) return Model
     with Global => null,
          Post   => Total_Bytes (Create'Result) = 0
            and then Used_This_Tick (Create'Result) = 0
            and then Budget (Create'Result) = Budget_Per_Tick;

   procedure Reset (M : in out Model)
     with Global => null,
          Post   => Total_Bytes (M) = 0
            and then Used_This_Tick (M) = 0
            and then Budget (M) = Budget (M'Old);

   --  Start a new accounting tick (clears per-tick usage only).
   procedure Advance_Tick (M : in out Model)
     with Global => null,
          Post   => Used_This_Tick (M) = 0
            and then Total_Bytes (M) = Total_Bytes (M'Old)
            and then Budget (M) = Budget (M'Old);

   --  Record a transfer. Rejects misaligned Size or over budget / capacity.
   --  Alignment rule: Size rem Alignment = 0.
   procedure Record_Transfer
     (M          : in out Model;
      Size       : Transfer_Size;
      Alignment  : Align_Value;
      Dir        : Direction;
      Ok         : out Boolean)
     with Global => null,
          Post   =>
            (if Size rem Alignment /= 0
               or else Used_This_Tick (M'Old) > Budget (M'Old)
               or else Size > Budget (M'Old) - Used_This_Tick (M'Old)
               or else Size > Max_Total_Bytes - Total_Bytes (M'Old)
             then
               not Ok
               and then Total_Bytes (M) = Total_Bytes (M'Old)
               and then Used_This_Tick (M) = Used_This_Tick (M'Old)
             else
               Ok
               and then Total_Bytes (M) = Total_Bytes (M'Old) + Size
               and then Used_This_Tick (M) = Used_This_Tick (M'Old) + Size);

private

   type Model is record
      H2D_Total   : Byte_Count := 0;
      D2H_Total   : Byte_Count := 0;
      Tick_Used   : Byte_Count := 0;
      Tick_Budget : Budget_Value := Default_Budget;
   end record
     with Type_Invariant =>
       Model.D2H_Total <= Max_Total_Bytes - Model.H2D_Total
       and then Model.Tick_Used <= Max_Total_Bytes;

   function Total_H2D (M : Model) return Byte_Count is (M.H2D_Total);

   function Total_D2H (M : Model) return Byte_Count is (M.D2H_Total);

   function Total_Bytes (M : Model) return Byte_Count is
     (M.H2D_Total + M.D2H_Total);

   function Used_This_Tick (M : Model) return Byte_Count is (M.Tick_Used);

   function Budget (M : Model) return Budget_Value is (M.Tick_Budget);

end PCIe_Transfer_Model;
