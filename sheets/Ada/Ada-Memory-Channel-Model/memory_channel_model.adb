pragma SPARK_Mode (On);

package body Memory_Channel_Model is

   function Create return Model is
   begin
      return (Channels => [others => [others => (Open => False, Row => 0)]],
              Bytes    => 0,
              Hits     => 0,
              Misses   => 0);
   end Create;

   procedure Reset (M : out Model) is
   begin
      M := Create;
   end Reset;

   procedure Open_Row
     (M       : in out Model;
      Channel : Channel_Id;
      Bank    : Bank_Id;
      Row     : Row_Id)
   is
      B : Bank_State renames M.Channels (Channel) (Bank);
   begin
      if B.Open and then B.Row = Row then
         M.Hits := M.Hits + 1;
      else
         M.Misses := M.Misses + 1;
         B.Open := True;
         B.Row := Row;
      end if;
   end Open_Row;

   procedure Close
     (M       : in out Model;
      Channel : Channel_Id;
      Bank    : Bank_Id)
   is
   begin
      M.Channels (Channel) (Bank).Open := False;
   end Close;

   procedure Ensure_Row
     (M          : in out Model;
      Channel    : Channel_Id;
      Bank       : Bank_Id;
      Target_Row : Row_Id)
   with
     Global => null,
     Pre    => Row_Hits (M) < Max_Events
       and then Row_Misses (M) < Max_Events,
     Post   => M.Channels (Channel) (Bank).Open
       and then M.Channels (Channel) (Bank).Row = Target_Row
       and then Bytes_Transferred (M) = Bytes_Transferred (M'Old)
       and then Row_Hits (M) <= Row_Hits (M'Old) + 1
       and then Row_Misses (M) <= Row_Misses (M'Old) + 1
       and then Row_Hits (M) + Row_Misses (M)
                = Row_Hits (M'Old) + Row_Misses (M'Old) + 1;

   procedure Ensure_Row
     (M          : in out Model;
      Channel    : Channel_Id;
      Bank       : Bank_Id;
      Target_Row : Row_Id)
   is
      B : Bank_State renames M.Channels (Channel) (Bank);
   begin
      if B.Open and then B.Row = Target_Row then
         M.Hits := M.Hits + 1;
      else
         M.Misses := M.Misses + 1;
         B.Open := True;
         B.Row := Target_Row;
      end if;
   end Ensure_Row;

   procedure Read
     (M          : in out Model;
      Channel    : Channel_Id;
      Bank       : Bank_Id;
      Target_Row : Row_Id;
      Size       : Burst_Size;
      Ok         : out Boolean)
   is
   begin
      Ensure_Row (M, Channel, Bank, Target_Row);
      M.Bytes := M.Bytes + Size;
      Ok := True;
   end Read;

   procedure Write
     (M          : in out Model;
      Channel    : Channel_Id;
      Bank       : Bank_Id;
      Target_Row : Row_Id;
      Size       : Burst_Size;
      Ok         : out Boolean)
   is
   begin
      Ensure_Row (M, Channel, Bank, Target_Row);
      M.Bytes := M.Bytes + Size;
      Ok := True;
   end Write;

end Memory_Channel_Model;
