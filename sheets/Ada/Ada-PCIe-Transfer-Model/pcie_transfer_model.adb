pragma SPARK_Mode (On);

package body PCIe_Transfer_Model is

   function Create
     (Budget_Per_Tick : Budget_Value := Default_Budget) return Model
   is
   begin
      return (H2D_Total   => 0,
              D2H_Total   => 0,
              Tick_Used   => 0,
              Tick_Budget => Budget_Per_Tick);
   end Create;

   procedure Reset (M : in out Model) is
      B : constant Budget_Value := M.Tick_Budget;
   begin
      M := (H2D_Total   => 0,
            D2H_Total   => 0,
            Tick_Used   => 0,
            Tick_Budget => B);
   end Reset;

   procedure Advance_Tick (M : in out Model) is
   begin
      M.Tick_Used := 0;
   end Advance_Tick;

   procedure Record_Transfer
     (M         : in out Model;
      Size      : Transfer_Size;
      Alignment : Align_Value;
      Dir       : Direction;
      Ok        : out Boolean)
   is
      Remaining_Budget : Byte_Count;
      Remaining_Cap    : Byte_Count;
   begin
      if Size rem Alignment /= 0 then
         Ok := False;
         return;
      end if;

      if M.Tick_Used > M.Tick_Budget then
         Ok := False;
         return;
      end if;

      Remaining_Budget := M.Tick_Budget - M.Tick_Used;
      if Size > Remaining_Budget then
         Ok := False;
         return;
      end if;

      Remaining_Cap := Max_Total_Bytes - Total_Bytes (M);
      if Size > Remaining_Cap then
         Ok := False;
         return;
      end if;

      case Dir is
         when H2D =>
            M.H2D_Total := M.H2D_Total + Size;
         when D2H =>
            M.D2H_Total := M.D2H_Total + Size;
      end case;
      M.Tick_Used := M.Tick_Used + Size;
      Ok := True;
   end Record_Transfer;

end PCIe_Transfer_Model;
