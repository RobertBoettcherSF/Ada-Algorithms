pragma Ada_2022;
package Design_Number_Container_System with SPARK_Mode => On is
   Capacity : constant := 16; subtype Count_Type is Natural range 0 .. Capacity; type Container is private;
   procedure Initialize (C : out Container); procedure Add (C : in out Container; Value : Integer); procedure Remove_Last (C : in out Container; Value : out Integer);
   function Contains (C : Container; Value : Integer) return Boolean; function Length (C : Container) return Count_Type;
private
   subtype Index_Type is Positive range 1 .. Capacity; type Items is array (Index_Type) of Integer; type Container is record Data : Items; Count : Count_Type; end record;
end Design_Number_Container_System;
