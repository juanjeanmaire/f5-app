import { IsOptional, IsString, IsUrl, Length } from 'class-validator';

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  @Length(2, 60)
  name?: string;

  @IsOptional()
  @IsString()
  @Length(1, 40)
  nickname?: string;

  @IsOptional()
  @IsUrl()
  avatarUrl?: string;

  /// Id de un equipo de la lista fija que maneja el front (ver
  /// lib/core/theme/league_teams.dart en Flutter) — no se valida contra
  /// una lista acá a propósito, para no duplicar/desincronizar esa data.
  @IsOptional()
  @IsString()
  @Length(1, 60)
  favoriteTeamId?: string;
}
