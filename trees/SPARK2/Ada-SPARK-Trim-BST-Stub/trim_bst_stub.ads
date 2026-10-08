pragma Ada_2022;

package Trim_BST_Stub with SPARK_Mode => On is
   Capacity : constant := 31;
   subtype Index is Natural range 0 .. Capacity;
   subtype Slot is Positive range 1 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type Tree is private;

   function Empty return Tree with Global => null;
   procedure Insert (T : in out Tree; V : Value)
     with Global => null, Pre => Size (T) < Capacity;
   procedure Trim (T : in out Tree; Low, High : Value) with Global => null;
   function Size (T : Tree) return Natural with Global => null;
   function Contains (T : Tree; V : Value) return Boolean with Global => null;
private
   type Value_Array is array (Slot) of Value;
   type Used_Array is array (Slot) of Boolean;
   type Tree is record
      Values : Value_Array;
      Used : Used_Array;
      Count : Index;
   end record;
end Trim_BST_Stub;
