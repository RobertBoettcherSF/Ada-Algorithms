pragma SPARK_Mode (On);

package Copy_List_With_Random_Pointer_Lite is
   subtype Count is Natural range 0 .. 16;
   subtype Position is Count range 1 .. 16;
   subtype Value is Integer range -100 .. 100;
   subtype Link_Index is Count;
   type List is private;

   function Empty return List;
   procedure Append (L : in out List; V : Value);
   procedure Set_Random (L : in out List; P : Position; Target : Link_Index)
     with Pre => P <= Length (L) and then Target <= Length (L);
   function Length (L : List) return Count;
   function Element (L : List; P : Position) return Value
     with Pre => P <= Length (L);
   function Random_Of (L : List; P : Position) return Link_Index
     with Pre => P <= Length (L);
   function Copy_List (L : List) return List;
private
   type Value_Array is array (Position) of Value;
   type Link_Array is array (Position) of Link_Index;
   type List is record
      Data : Value_Array := (others => 0);
      Random : Link_Array := (others => 0);
      Size : Count := 0;
   end record;
end Copy_List_With_Random_Pointer_Lite;
