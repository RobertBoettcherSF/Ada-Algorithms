pragma Ada_2022;
package One_Edit_Distance with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;
   procedure Is_One_Edit (Left, Right : Text; Left_Length, Right_Length : Length_Type;
                          Result : out Boolean)
     with Global => null;
end One_Edit_Distance;
