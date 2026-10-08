pragma SPARK_Mode (On);

package Online_Stock_Span_Stub is
   Capacity : constant := 8;
   subtype Price_Index is Positive range 1 .. Capacity;
   subtype Used_Count is Natural range 0 .. Capacity;
   subtype Price is Natural range 0 .. 1000;
   subtype Span_Value is Positive range 1 .. Capacity;
   type Price_Array is array (Price_Index) of Price;

   type State is record
      Count : Used_Count := 0;
      Prices : Price_Array := (others => 0);
   end record;

   procedure Initialize (S : out State) with Global => null;

   procedure Next
     (S : in out State; P : Price; Result : out Span_Value)
     with
       Global => null,
       Pre => S.Count < Capacity;
end Online_Stock_Span_Stub;
