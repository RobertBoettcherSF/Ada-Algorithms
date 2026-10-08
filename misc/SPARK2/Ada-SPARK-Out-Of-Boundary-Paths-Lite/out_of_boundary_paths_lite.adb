pragma Ada_2022;
package body Out_Of_Boundary_Paths_Lite with SPARK_Mode => On is
   function Immediate_Exits (Row, Col : Coordinate) return Exit_Count is
      Result : Exit_Count := 0;
   begin
      if Row = 1 then Result := Result + 1; end if;
      if Row = 4 then Result := Result + 1; end if;
      if Col = 1 then Result := Result + 1; end if;
      if Col = 4 then Result := Result + 1; end if;
      return Result;
   end Immediate_Exits;
end Out_Of_Boundary_Paths_Lite;
