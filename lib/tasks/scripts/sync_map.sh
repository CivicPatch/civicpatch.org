SHAPEFILE_PATH=$1
type=$2

ogr2ogr \
  -f "PostgreSQL" \
  PG:"dbname=$POSTGRES_DB user=$POSTGRES_USER host=$POSTGRES_HOST password=$POSTGRES_PASSWORD port=5432" \
  $SHAPEFILE_PATH \
  -nln ${type}s \
  -nlt PROMOTE_TO_MULTI \
  -lco GEOMETRY_NAME=geom \
  -lco FID=gid \
  -lco PRECISION=NO \
  -append

if [ "$type" = "place" ]; then
  PGPASSWORD=$POSTGRES_PASSWORD psql \
    -U $POSTGRES_USER \
    -d $POSTGRES_DB \
    -h $POSTGRES_HOST \
    -c "DELETE FROM places WHERE gid NOT IN (SELECT MAX(gid) FROM places GROUP BY statefp, placefp);"
fi
