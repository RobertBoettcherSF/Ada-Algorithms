pragma Ada_2022;
package Time_Based_Key_Value_Store with SPARK_Mode => On is
   Capacity : constant := 8; subtype Key_Type is Natural range 0 .. Capacity - 1; subtype Time_Type is Natural range 0 .. 1000;
   procedure Initialize; procedure Put (Key : Key_Type; Value : Integer; At_Time : Time_Type); function Get (Key : Key_Type; At_Time : Time_Type) return Integer;
private
   type Slot is record Value : Integer; Stamp : Time_Type; Valid : Boolean; end record; type Table is array (Key_Type) of Slot; Store : Table;
end Time_Based_Key_Value_Store;
