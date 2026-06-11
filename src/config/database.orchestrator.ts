import { Module, Global } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigService } from '@nestjs/config';

@Global()
@Module({
  imports: [
    // PostgreSQL Configuration via TypeORM
    TypeOrmModule.forRootAsync({
      useFactory: () => ({
        type: 'postgres',
        host: process.env.POSTGRES_HOST || 'localhost',
        port: parseInt(process.env.POSTGRES_PORT || '5432', 10),
        username: process.env.POSTGRES_USER || 'admin',
        password: process.env.POSTGRES_PASSWORD || 'secret',
        database: process.env.POSTGRES_DB || 'the_salon_app',
        autoLoadEntities: true,
        synchronize:
          process.env.DB_SYNCHRONIZE === 'true' &&
          process.env.NODE_ENV !== 'production',
        logging: process.env.DB_LOGGING === 'true',
      }),
    }),
    
    // MongoDB Configuration via Mongoose
    MongooseModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        uri:
          config.get<string>('MONGO_URI') ||
          'mongodb://localhost:27017/salon_ai_logs',
        lazyConnection: config.get<string>('MONGO_ENABLED') !== 'true',
        retryAttempts: 1,
        connectionFactory: (connection) => {
          connection.on('connected', () => {
            console.log('MongoDB successfully connected');
          });
          connection.on('error', (err: any) => {
            console.error('MongoDB connection error:', err);
          });
          return connection;
        },
      }),
    }),
  ],
  exports: [TypeOrmModule, MongooseModule],
})
export class DatabaseOrchestratorModule {}
