pragma SPARK_Mode (On);

package body Min_Max_Normalize is
   function Normalize (Samples : Sample_Array; Position : Index)
     return Normalized_Value is
      Small : Sample_Value := Samples (Index'First);
      Large : Sample_Value := Samples (Index'First);
      Span  : Integer range 0 .. 10;
      Offset : Integer range 0 .. 10;
   begin
      for I in Index loop
         if Samples (I) < Small then
            Small := Samples (I);
         end if;
         if Samples (I) > Large then
            Large := Samples (I);
         end if;
      end loop;
      Span := Large - Small;
      Offset := Samples (Position) - Small;
      pragma Assert (Offset <= Span);
      case Span is
         when 0 => return 0;
         when 1 => return Offset * 100;
         when 2 => return (Offset * 100) / 2;
         when 3 => return (Offset * 100) / 3;
         when 4 => return (Offset * 100) / 4;
         when 5 => return (Offset * 100) / 5;
         when 6 => return (Offset * 100) / 6;
         when 7 => return (Offset * 100) / 7;
         when 8 => return (Offset * 100) / 8;
         when 9 => return (Offset * 100) / 9;
         when 10 => return Offset * 10;
      end case;
   end Normalize;
end Min_Max_Normalize;
