import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import {
  HairstyleService,
  BeardService,
  NailService,
  TryOnResultService,
  RecommendationService,
} from './services';
import {
  CreateHairstyleDto,
  UpdateHairstyleDto,
  GetHairstylesDto,
  CreateBeardDto,
  UpdateBeardDto,
  GetBeardsDto,
  CreateNailDto,
  UpdateNailDto,
  GetNailsDto,
  SaveTryOnResultDto,
  GetTryOnResultsDto,
  ShareTryOnResultDto,
  GetRecommendationsDto,
} from './dto';

@Controller('api/ar-tryon')
export class ArTryonController {
  constructor(
    private hairstyleService: HairstyleService,
    private beardService: BeardService,
    private nailService: NailService,
    private tryOnResultService: TryOnResultService,
    private recommendationService: RecommendationService,
  ) {}

  // ==================== HAIRSTYLES ====================

  @Post('hairstyles')
  async createHairstyle(@Body() dto: CreateHairstyleDto) {
    return this.hairstyleService.create(dto);
  }

  @Get('hairstyles')
  async getHairstyles(@Query() query: GetHairstylesDto) {
    return this.hairstyleService.findAll(query);
  }

  @Get('hairstyles/popular')
  async getPopularHairstyles() {
    return this.hairstyleService.getPopular(10);
  }

  @Get('hairstyles/:id')
  async getHairstyle(@Param('id') id: string) {
    return this.hairstyleService.findById(id);
  }

  @Put('hairstyles/:id')
  async updateHairstyle(
    @Param('id') id: string,
    @Body() dto: UpdateHairstyleDto,
  ) {
    return this.hairstyleService.update(id, dto);
  }

  @Delete('hairstyles/:id')
  async deleteHairstyle(@Param('id') id: string) {
    await this.hairstyleService.delete(id);
    return { message: 'Hairstyle deleted successfully' };
  }

  // ==================== BEARDS ====================

  @Post('beards')
  async createBeard(@Body() dto: CreateBeardDto) {
    return this.beardService.create(dto);
  }

  @Get('beards')
  async getBeards(@Query() query: GetBeardsDto) {
    return this.beardService.findAll(query);
  }

  @Get('beards/popular')
  async getPopularBeards() {
    return this.beardService.getPopular(10);
  }

  @Get('beards/:id')
  async getBeard(@Param('id') id: string) {
    return this.beardService.findById(id);
  }

  @Put('beards/:id')
  async updateBeard(@Param('id') id: string, @Body() dto: UpdateBeardDto) {
    return this.beardService.update(id, dto);
  }

  @Delete('beards/:id')
  async deleteBeard(@Param('id') id: string) {
    await this.beardService.delete(id);
    return { message: 'Beard deleted successfully' };
  }

  // ==================== NAILS ====================

  @Post('nails')
  async createNail(@Body() dto: CreateNailDto) {
    return this.nailService.create(dto);
  }

  @Get('nails')
  async getNails(@Query() query: GetNailsDto) {
    return this.nailService.findAll(query);
  }

  @Get('nails/popular')
  async getPopularNails() {
    return this.nailService.getPopular(10);
  }

  @Get('nails/:id')
  async getNail(@Param('id') id: string) {
    return this.nailService.findById(id);
  }

  @Put('nails/:id')
  async updateNail(@Param('id') id: string, @Body() dto: UpdateNailDto) {
    return this.nailService.update(id, dto);
  }

  @Delete('nails/:id')
  async deleteNail(@Param('id') id: string) {
    await this.nailService.delete(id);
    return { message: 'Nail deleted successfully' };
  }

  // ==================== RECOMMENDATIONS ====================

  @Get('recommendations')
  async getRecommendations(@Query() query: GetRecommendationsDto, @Request() req) {
    const userId = req.user?.id || 'anonymous';
    return this.recommendationService.getRecommendations(userId, query);
  }

  @Post('recommendations/analyze-face')
  async analyzeFace(
    @Body()
    faceAnalysis: {
      faceShape?: string;
      skinTone?: string;
      faceWidth?: number;
      faceLength?: number;
      jawlineWidth?: number;
    },
    @Request() req,
  ) {
    const userId = req.user?.id;
    if (!userId) {
      return { error: 'User not authenticated' };
    }
    return this.recommendationService.saveUserAnalysis(userId, faceAnalysis);
  }

  @Post('recommendations/prefer/:type/:styleId')
  async addToPreferred(
    @Param('type') type: 'hairstyle' | 'beard' | 'nail',
    @Param('styleId') styleId: string,
    @Request() req,
  ) {
    const userId = req.user?.id;
    if (!userId) {
      return { error: 'User not authenticated' };
    }
    return this.recommendationService.addToPreferred(userId, type, styleId);
  }

  @Delete('recommendations/prefer/:type/:styleId')
  async removeFromPreferred(
    @Param('type') type: 'hairstyle' | 'beard' | 'nail',
    @Param('styleId') styleId: string,
    @Request() req,
  ) {
    const userId = req.user?.id;
    if (!userId) {
      return { error: 'User not authenticated' };
    }
    return this.recommendationService.removeFromPreferred(userId, type, styleId);
  }

  // ==================== TRY-ON RESULTS ====================

  @Post('results')
  async saveResult(@Body() dto: SaveTryOnResultDto, @Request() req) {
    const userId = req.user?.id;
    if (!userId) {
      return { error: 'User not authenticated' };
    }
    return this.tryOnResultService.save(userId, dto);
  }

  @Get('results')
  async getUserResults(@Query() query: GetTryOnResultsDto, @Request() req) {
    const userId = req.user?.id;
    if (!userId) {
      return { error: 'User not authenticated' };
    }
    return this.tryOnResultService.findByUserId(userId, query);
  }

  @Get('results/:id')
  async getResult(@Param('id') id: string) {
    return this.tryOnResultService.findById(id);
  }

  @Post('results/:id/share')
  async shareResult(
    @Param('id') id: string,
    @Body() dto: ShareTryOnResultDto,
  ) {
    return this.tryOnResultService.share(id, dto);
  }

  @Get('results/shared/:shareToken')
  async getSharedResult(@Param('shareToken') shareToken: string) {
    return this.tryOnResultService.findByShareToken(shareToken);
  }

  @Delete('results/:id')
  async deleteResult(@Param('id') id: string) {
    await this.tryOnResultService.delete(id);
    return { message: 'Result deleted successfully' };
  }

  @Get('results/stats/user')
  async getUserStats(@Request() req) {
    const userId = req.user?.id;
    if (!userId) {
      return { error: 'User not authenticated' };
    }
    return this.tryOnResultService.getStats(userId);
  }
}
