pragma SPARK_Mode (On);

--  Micron-flavoured *educational* DRAM channel model.
--  Abstract small integers only — NOT real DDR timings from datasheets.
--  No proprietary Micron headers or vendor IP.

package Memory_Channel_Model is

   Channel_Count : constant := 2;
   Bank_Count    : constant := 2;
   Max_Row       : constant := 7;
   Max_Burst     : constant := 64;
   Max_Bytes     : constant := 4096;
   Max_Events    : constant := 1024;

   subtype Channel_Id is Natural range 0 .. Channel_Count - 1;
   subtype Bank_Id    is Natural range 0 .. Bank_Count - 1;
   subtype Row_Id     is Natural range 0 .. Max_Row;
   subtype Burst_Size is Positive range 1 .. Max_Burst;
   subtype Byte_Count is Natural range 0 .. Max_Bytes;
   subtype Event_Count is Natural range 0 .. Max_Events;

   type Model is private;

   function Bytes_Transferred (M : Model) return Byte_Count
     with Global => null;

   function Row_Hits (M : Model) return Event_Count
     with Global => null;

   function Row_Misses (M : Model) return Event_Count
     with Global => null;

   function Create return Model
     with Global => null,
          Post   => Bytes_Transferred (Create'Result) = 0
            and then Row_Hits (Create'Result) = 0
            and then Row_Misses (Create'Result) = 0;

   procedure Reset (M : out Model)
     with Global => null,
          Post   => Bytes_Transferred (M) = 0
            and then Row_Hits (M) = 0
            and then Row_Misses (M) = 0;

   --  Open a row on (Channel, Bank). Closing any previous open row first
   --  counts as a miss when switching rows; re-open same row is a hit.
   procedure Open_Row
     (M       : in out Model;
      Channel : Channel_Id;
      Bank    : Bank_Id;
      Row     : Row_Id)
     with Global => null,
          Pre    => Row_Hits (M) < Max_Events
            and then Row_Misses (M) < Max_Events,
          Post   => Bytes_Transferred (M) = Bytes_Transferred (M'Old);

   procedure Close
     (M       : in out Model;
      Channel : Channel_Id;
      Bank    : Bank_Id)
     with Global => null,
          Post   => Bytes_Transferred (M) = Bytes_Transferred (M'Old)
            and then Row_Hits (M) = Row_Hits (M'Old)
            and then Row_Misses (M) = Row_Misses (M'Old);

   --  Read/Write require an open row on that bank; conflict (wrong/no row)
   --  auto-opens Target_Row and counts a miss; matching open row = hit.
   procedure Read
     (M          : in out Model;
      Channel    : Channel_Id;
      Bank       : Bank_Id;
      Target_Row : Row_Id;
      Size       : Burst_Size;
      Ok         : out Boolean)
     with Global => null,
          Pre    => Bytes_Transferred (M) <= Max_Bytes - Size
            and then Row_Hits (M) < Max_Events
            and then Row_Misses (M) < Max_Events,
          Post   =>
            (if Ok then
               Bytes_Transferred (M) = Bytes_Transferred (M'Old) + Size
             else
               Bytes_Transferred (M) = Bytes_Transferred (M'Old));

   procedure Write
     (M          : in out Model;
      Channel    : Channel_Id;
      Bank       : Bank_Id;
      Target_Row : Row_Id;
      Size       : Burst_Size;
      Ok         : out Boolean)
     with Global => null,
          Pre    => Bytes_Transferred (M) <= Max_Bytes - Size
            and then Row_Hits (M) < Max_Events
            and then Row_Misses (M) < Max_Events,
          Post   =>
            (if Ok then
               Bytes_Transferred (M) = Bytes_Transferred (M'Old) + Size
             else
               Bytes_Transferred (M) = Bytes_Transferred (M'Old));

private

   type Bank_State is record
      Open   : Boolean := False;
      Row    : Row_Id := 0;
   end record;

   type Bank_Array is array (Bank_Id) of Bank_State;
   type Channel_Array is array (Channel_Id) of Bank_Array;

   type Model is record
      Channels : Channel_Array := [others => [others => (Open => False, Row => 0)]];
      Bytes    : Byte_Count := 0;
      Hits     : Event_Count := 0;
      Misses   : Event_Count := 0;
   end record;

   function Bytes_Transferred (M : Model) return Byte_Count is (M.Bytes);

   function Row_Hits (M : Model) return Event_Count is (M.Hits);

   function Row_Misses (M : Model) return Event_Count is (M.Misses);

end Memory_Channel_Model;
