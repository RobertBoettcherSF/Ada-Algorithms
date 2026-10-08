pragma Ada_2022;
package Design_Food_Rating_System with SPARK_Mode => On is
   subtype Rating is Natural range 0 .. 5; procedure Initialize; procedure Set_Rating (Value : Rating); function Current_Rating return Rating;
private Current : Rating := 0;
end Design_Food_Rating_System;
