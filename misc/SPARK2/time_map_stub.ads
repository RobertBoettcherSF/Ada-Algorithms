pragma SPARK_Mode (On);

package Time_Map_Stub is
   Entry_Count : constant := 4;
   subtype Entry_Index is Positive range 1 .. Entry_Count;
   subtype Used_Count is Natural range 0 .. Entry_Count;
   subtype Timestamp is Natural range 0 .. 100;
   subtype Stored_Value is Integer range -1000 .. 1000;
   No_Value : constant Stored_Value := -1000;
   type Map_Entry is record
      Stamp : Timestamp;
      Value : Stored_Value;
   end record;
   type Entry_Array is array (Entry_Index) of Map_Entry;

   function Value_At
     (Entries : Entry_Array; Used : Used_Count;
      Query_Time : Timestamp) return Stored_Value;
end Time_Map_Stub;
