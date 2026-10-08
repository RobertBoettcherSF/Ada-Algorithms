pragma Ada_2022;
package Shortest_Word_Distance with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   subtype Distance_Type is Natural range 0 .. 32;
   type Text is array (Index) of Character;
   procedure Minimum_Distance (Input : Text; Length : Length_Type;
                               First, Second : Character; Result : out Distance_Type)
     with Global => null;
end Shortest_Word_Distance;
