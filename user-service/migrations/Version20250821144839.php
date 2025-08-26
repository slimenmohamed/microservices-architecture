<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Initial schema: create users table (id, name, email unique)
 */
final class Version20250821144839 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Create users table with unique email';
    }

    public function up(Schema $schema): void
    {
        // MySQL platform only for this project
        $this->abortIf($this->connection->getDatabasePlatform()->getName() !== 'mysql', 'Migration can only be executed safely on \"mysql\".');

        $this->addSql('CREATE TABLE IF NOT EXISTS users (
          id INT AUTO_INCREMENT NOT NULL,
          name VARCHAR(255) NOT NULL,
          email VARCHAR(255) NOT NULL,
          UNIQUE INDEX UNIQ_USERS_EMAIL (email),
          PRIMARY KEY(id)
        ) DEFAULT CHARACTER SET utf8mb4 COLLATE `utf8mb4_unicode_ci` ENGINE = InnoDB');
    }

    public function down(Schema $schema): void
    {
        $this->abortIf($this->connection->getDatabasePlatform()->getName() !== 'mysql', 'Migration can only be executed safely on \"mysql\".');

        $this->addSql('DROP TABLE IF EXISTS users');
    }
}
