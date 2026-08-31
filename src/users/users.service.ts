import { Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { ChangePasswordDto } from './dto/change-password.dto';

const SALT_ROUNDS = 10;

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Usuario no encontrado');

    const memberships = await this.prisma.groupMembership.findMany({
      where: { userId },
      include: { group: true },
    });

    return { ...this.toPublicUser(user), memberships };
  }

  async updateMe(userId: string, dto: UpdateUserDto) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        name: dto.name,
        nickname: dto.nickname,
        avatarUrl: dto.avatarUrl,
        favoriteTeamId: dto.favoriteTeamId,
      },
    });
    return this.toPublicUser(user);
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Usuario no encontrado');

    if (user.passwordHash) {
      const matches = await bcrypt.compare(dto.currentPassword, user.passwordHash);
      if (!matches) {
        throw new UnauthorizedException('La contraseña actual no es correcta');
      }
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, SALT_ROUNDS);
    await this.prisma.user.update({ where: { id: userId }, data: { passwordHash } });
    return { message: 'Contraseña actualizada' };
  }

  /** Nunca devolver el hash de la contraseña ni el token de sesión al cliente. */
  private toPublicUser(user: {
    passwordHash?: string | null;
    activeSessionToken?: string | null;
    [key: string]: unknown;
  }) {
    const { passwordHash, activeSessionToken, ...rest } = user;
    return rest;
  }
}
