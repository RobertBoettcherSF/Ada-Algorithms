-- arc_cache.ads
pragma Ada_2012;

with Ada.Containers.Hashed_Maps;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers;

--  Generic Adaptive Replacement Cache (ARC) package.
--  Implements the standard ARC algorithm by Nimrod Megiddo and Dharmendra Modha.
--  Also supports the ZFS variant explicitly allowing for locked pages that 
--  cannot be vacated while in use.
--  OpenZFS L2ARC variant is natively supported by instantiating Value_Type
--  with SSD block identifiers instead of RAM pointers/data.

generic
   type Key_Type is private;
   type Value_Type is private;
   with function Hash (Key : Key_Type) return Ada.Containers.Hash_Type;
   with function "=" (Left, Right : Key_Type) return Boolean is <>;
package ARC_Cache is

   type Cache (Capacity : Ada.Containers.Count_Type) is tagged private;

   Cache_Full_Of_Locked_Pages : exception;

   --  Standard ARC operations
   procedure Put (C : in out Cache; Key : Key_Type; Value : Value_Type);
   function Get (C : in out Cache; Key : Key_Type; Value : out Value_Type) return Boolean;

   --  Variant operations (ZFS style: Pinned/Locked pages that cannot be evicted)
   procedure Put_Locked (C : in out Cache; Key : Key_Type; Value : Value_Type);
   function Get_Locked (C : in out Cache; Key : Key_Type; Value : out Value_Type) return Boolean;
   procedure Unlock (C : in out Cache; Key : Key_Type);
   function Is_Locked (C : Cache; Key : Key_Type) return Boolean;

private
   use Ada.Containers;

   type List_Kind is (In_T1, In_T2, In_B1, In_B2);

   package Key_Lists is new Ada.Containers.Doubly_Linked_Lists (Key_Type);

   type Cache_Entry is record
      Kind   : List_Kind := In_T1;
      Value  : Value_Type;
      Pos    : Key_Lists.Cursor;
      Locked : Boolean := False;
   end record;

   package Cache_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Key_Type,
      Element_Type    => Cache_Entry,
      Hash            => Hash,
      Equivalent_Keys => "=");

   type List_Array is array (List_Kind) of Key_Lists.List;

   type Cache (Capacity : Count_Type) is tagged record
      Map   : Cache_Maps.Map;
      Lists : List_Array;
      P     : Integer := 0;  -- Target size for T1
   end record;

end ARC_Cache;
