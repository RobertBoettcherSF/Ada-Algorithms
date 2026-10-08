pragma Ada_2022;
package body Design_Food_Rating_System with SPARK_Mode => On is
   procedure Initialize is begin Current := 0; end Initialize;
   procedure Set_Rating (Value : Rating) is begin Current := Value; end Set_Rating;
   function Current_Rating return Rating is (Current);
end Design_Food_Rating_System;
